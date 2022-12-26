module AttendancesHelper

  def attendance_state(attendance)
    # 受け取ったAttendanceオブジェクトが当日と一致するか評価します。
    if Date.current == attendance.worked_on
      return '出社' if attendance.started_at.nil?
      return '退社' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    # どれにも当てはまらなかった場合はfalseを返します。
    return false
  end
  
  def time_ceil_quarter(time)
    min = time.min
    
    case min
    when 1..15
      q = 15
    when 16..30
      q = 30
    when 31..45
      q = 45
    when 46..59
      q = 60
    else
      q = 0
    end
    
    time += (q-min).minutes
  end

  # 出勤時間と退勤時間を受け取り、在社時間を計算して返します。
  def working_times(start, finish)
    format("%.2f", (((finish - start) / 60) / 60.0))
  end
end
