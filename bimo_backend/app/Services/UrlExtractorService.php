<?php

namespace App\Services;

use Exception;
use Illuminate\Support\Facades\Http;

class UrlExtractorService
{
    /**
     * Fetch URL content safely and extract readable text.
     *
     * @param string $url
     * @return string
     * @throws Exception
     */
    public function extractContent(string $url): string
    {
        $url = trim($url);

        if (!filter_var($url, FILTER_VALIDATE_URL)) {
            throw new Exception("Invalid URL format.");
        }

        $parsed = parse_url($url);
        $scheme = strtolower($parsed['scheme'] ?? '');
        if (!in_array($scheme, ['http', 'https'], true)) {
            throw new Exception("Only HTTP and HTTPS URLs are allowed.");
        }

        $host = $parsed['host'] ?? '';
        if (empty($host)) {
            throw new Exception("Invalid URL host.");
        }

        // SSRF protection: reject localhost and private IP addresses
        if (strtolower($host) === 'localhost' || $host === '127.0.0.1' || $host === '::1') {
            throw new Exception("Access to local addresses is prohibited.");
        }

        $ip = gethostbyname($host);
        if (filter_var($ip, FILTER_VALIDATE_IP)) {
            if (
                !filter_var(
                    $ip,
                    FILTER_VALIDATE_IP,
                    FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE
                )
            ) {
                throw new Exception("Access to private/internal network addresses is prohibited.");
            }
        }

        try {
            $response = Http::timeout(8)
                ->withHeaders([
                    'User-Agent' => 'BiMO-BOM-Extractor/1.0 (+https://bimo.app)',
                    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,text/plain;q=0.8,*/*;q=0.5',
                ])
                ->get($url);

            if (!$response->successful()) {
                throw new Exception("Failed to fetch URL: HTTP {$response->status()}");
            }

            $body = $response->body();
            // Cap to 512KB
            if (strlen($body) > 512 * 1024) {
                $body = substr($body, 0, 512 * 1024);
            }

            return $this->cleanHtmlContent($body);
        } catch (Exception $e) {
            throw new Exception("Could not extract content from URL: " . $e->getMessage());
        }
    }

    /**
     * Convert raw HTML into clean readable text for AI processing.
     *
     * @param string $html
     * @return string
     */
    public function cleanHtmlContent(string $html): string
    {
        // Remove script, style, and comments
        $html = preg_replace('/<script\b[^>]*>(.*?)<\/script>/is', ' ', $html);
        $html = preg_replace('/<style\b[^>]*>(.*?)<\/style>/is', ' ', $html);
        $html = preg_replace('/<!--(.*?)-->/is', ' ', $html);

        // Strip remaining HTML tags
        $text = strip_tags($html);

        // Decode HTML entities
        $text = html_entity_decode($text, ENT_QUOTES | ENT_HTML5, 'UTF-8');

        // Collapse whitespace
        $text = preg_replace('/[ \t]+/', ' ', $text);
        $text = preg_replace('/[\r\n]+/', "\n", $text);

        $text = trim($text);

        // Cap text output to ~8000 characters to keep prompt compact
        if (strlen($text) > 8000) {
            $text = substr($text, 0, 8000) . "\n...[truncated]";
        }

        return $text;
    }
}
