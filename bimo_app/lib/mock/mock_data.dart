import '../features/projects/domain/models.dart';

class MockData {
  MockData._();

  static List<ProjectModel> getInitialProjects() {
    return [];
  }

  static List<String> getSampleProjectIdeas() {
    return [
      "Solar-powered automatic plant watering system with ESP32",
      "IoT home air quality monitor with PM2.5 and CO2 sensors",
      "Autonomous obstacle-avoiding mobile robot with LIDAR",
      "Smart water tank level monitor with LoRaWAN wireless telemetry",
      "Portable solar generator box with LiFePO4 battery storage",
      "Automated hydroponic nutrient dosing station",
    ];
  }
}
