bool isValidLatitude(double latitude) {
  return latitude.isFinite && latitude >= -90 && latitude <= 90;
}

bool isValidLongitude(double longitude) {
  return longitude.isFinite && longitude >= -180 && longitude <= 180;
}

bool isValidCoordinate(double latitude, double longitude) {
  return isValidLatitude(latitude) && isValidLongitude(longitude);
}

bool isValidAccuracy(double accuracy) {
  return accuracy.isFinite && accuracy >= 0;
}
