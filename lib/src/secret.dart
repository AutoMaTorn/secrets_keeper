class Secret {
  String name;
  String value;

  Secret(this.name, this.value);

  Secret.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      value = json['secret'];

  Map<String, dynamic> toJson() {
    return {'name': name, 'secret': value};
  }
}
