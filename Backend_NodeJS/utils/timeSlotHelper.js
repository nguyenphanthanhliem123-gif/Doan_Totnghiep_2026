export function generateSlotsFromInterval(startTime, endTime, slotDuration, breakTime) {
    let slots = [];
    
    // Giả lập ngày để tính toán thời gian toán học bằng đối tượng Date
    let current = new Date(`2026-01-01T${startTime}`);
    const end = new Date(`2026-01-01T${endTime}`);
    
    while (current < end) {
        let nextSlotEnd = new Date(current.getTime() + slotDuration * 60000);
        
        // Nếu slot tiếp theo vượt quá giờ kết thúc ca thì dừng
        if (nextSlotEnd > end) break;
        
        let timeString = current.toTimeString().substring(0, 5); // Định dạng "HH:MM"
        slots.push(timeString);
        
        // Tiến tới slot tiếp theo = Thời gian khám + Thời gian nghỉ giữa ca
        current = new Date(nextSlotEnd.getTime() + breakTime * 60000);
    }
    
    return slots;
}