import dayjs from 'dayjs';

export function formatDateForFeishu(date: string | Date): string {
  const currentDate = dayjs(date);
  const currentYear = dayjs().year();
  const docYear = currentDate.year();

  const monthName = currentDate.format('MMMM');
  const day = currentDate.format('D');

  if (docYear === currentYear) {
    return `${monthName} ${day}`;
  } else {
    return `${docYear} ${monthName} ${day}`;
  }
}