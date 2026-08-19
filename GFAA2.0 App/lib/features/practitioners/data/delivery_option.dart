enum DeliveryOption {
  faceToFace('face_to_face', 'Face to face'),
  online('online', 'Online'),
  telephone('phone', 'Telephone');

  const DeliveryOption(this.key, this.label);

  final String key;
  final String label;

  static DeliveryOption fromKey(String key) => DeliveryOption.values.firstWhere((option) => option.key == key);
}
