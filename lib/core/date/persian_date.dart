import 'package:shamsi_date/shamsi_date.dart';

const _weekdays = [
  'دوشنبه',
  'سه‌شنبه',
  'چهارشنبه',
  'پنجشنبه',
  'جمعه',
  'شنبه',
  'یکشنبه',
];

const _months = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

String persianDateLabel(DateTime date) {
  final j = Jalali.fromDateTime(date);
  return '${_weekdays[date.weekday - 1]}، ${j.day} ${_months[j.month - 1]}';
}
