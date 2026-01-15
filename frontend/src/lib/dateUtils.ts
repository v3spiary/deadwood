// utils/dateUtils.ts
export function parseCustomDate(dateStr: string): Date {
  if (!dateStr) return new Date(0)
  
  // Try ISO format
  const isoDate = new Date(dateStr)
  if (!isNaN(isoDate.getTime())) return isoDate
  
  // Try custom format "DD.MM.YYYY HH:mm"
  if (dateStr.includes('.')) {
    const [datePart, timePart] = dateStr.split(' ')
    const [day, month, year] = datePart.split('.').map(Number)
    
    if (year && month && day) {
      let hours = 0, minutes = 0
      if (timePart) {
        [hours, minutes] = timePart.split(':').map(Number)
      }
      
      const date = new Date(year, month - 1, day, hours, minutes)
      if (!isNaN(date.getTime())) return date
    }
  }
  
  return new Date(0)
}

export function formatMessageTime(dateString: string): string {
  const date = parseCustomDate(dateString)
  if (date.getTime() === 0) return ''
  
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMs / 3600000)
  const diffDays = Math.floor(diffMs / 86400000)
  
  // Less than 1 minute
  if (diffMins < 1) return 'Только что'
  
  // Less than 1 hour
  if (diffMins < 60) return `${diffMins} мин назад`
  
  // Less than 24 hours
  if (diffHours < 24) return `${diffHours} ч назад`
  
  // Less than 7 days
  if (diffDays < 7) return `${diffDays} д назад`
  
  // Older dates
  return date.toLocaleDateString('ru-RU', {
    day: 'numeric',
    month: 'short',
    year: diffDays > 365 ? 'numeric' : undefined
  })
}