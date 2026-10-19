const subjects = {
  'math': 'Toán',
  'literature': 'Ngữ văn',
  'english': 'Tiếng Anh',
  'physics': 'Vật lý',
  'chemistry': 'Hóa học',
  'biology': 'Sinh học',
  'informatics': 'Tin học',
};
const levels = {
  'primary': 'Tiểu học',
  'secondary': 'THCS',
  'high': 'THPT',
  'university': 'Đại học',
  'other': 'Khác',
};
const teachingModes = {
  'offline': 'Trực tiếp',
  'online': 'Trực tuyến',
  'both': 'Cả hai',
};
const weekDays = [
  'Thứ hai',
  'Thứ ba',
  'Thứ tư',
  'Thứ năm',
  'Thứ sáu',
  'Thứ bảy',
  'Chủ nhật',
];
const dayPeriods = ['Sáng', 'Chiều', 'Tối'];
// Ô = ngày * 3 + buổi, thứ hai = 0. Dùng Set<int> để tính Jaccard ở GĐ4.
String slotLabel(int slot) =>
    '${weekDays[slot ~/ 3]} • ${dayPeriods[slot % 3]}';
