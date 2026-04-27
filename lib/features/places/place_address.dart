class PlaceAddress {
  const PlaceAddress({this.addressName, this.roadAddressName, this.regionName});

  final String? addressName;
  final String? roadAddressName;
  final String? regionName;
}

abstract interface class ReverseGeocoder {
  Future<PlaceAddress?> resolve({
    required double latitude,
    required double longitude,
  });
}
