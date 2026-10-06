String toPersianDigits(Object value) {
  const latin = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  return value.toString().split('').map((char) {
    final index = latin.indexOf(char);
    return index == -1 ? char : persian[index];
  }).join();
}
