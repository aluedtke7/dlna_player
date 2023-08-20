class WindowSettings {
  double posX = 0;
  double posY = 0;
  double sizeX = 500;
  double sizeY = 700;

  WindowSettings(
    this.posX,
    this.posY,
    this.sizeX,
    this.sizeY,
  );

  Map<String, dynamic> toJson() => {
        'posX': posX,
        'posY': posY,
        'sizeX': sizeX,
        'sizeY': sizeY,
      };

  WindowSettings.fromJson(Map<String, dynamic> json)
      : posX = json['posX'] ?? 0,
        posY = json['posY'] ?? 0,
        sizeX = json['sizeX'] ?? 0,
        sizeY = json['sizeY'] ?? 0;
}
