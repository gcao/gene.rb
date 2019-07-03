class Gene::Benchmarker
  class OpTime
    attr_accessor :name
    attr_accessor :count
    attr_accessor :total_time
    attr_accessor :recent_start_time

    def initialize name
      @name       = name
      @count      = 0
      @total_time = 0
    end

    def report_start time
      @recent_start_time = time
    end

    def report_partial time
      @total_time += time.to_f - @recent_start_time.to_f
    end

    def report_end time
      @count += 1
      @total_time += time.to_f - @recent_start_time.to_f
    end

    def average_time
      @total_time / @count
    end
  end

  attr_reader :loop_time
  attr_reader :op_times

  def initialize
    @loop_time = OpTime.new 'loop'
    @op_times  = {}
  end

  def loop_start time
    loop_time.report_start time
  end

  def loop_end time
    loop_time.report_end time
  end

  def op_start op, time
    found = @op_times[op]
    if not found
      found = @op_times[op] = OpTime.new(op)
    end
    found.report_start time
  end

  def op_end op, time
    found = @op_times[op]
    found.report_end time
  end

  def total_time
    loop_time.total_time + op_times.values.reduce(0) {|sum, op_time| sum + op_time.total_time.to_f }
  end

  def sort_order
    ENV['SORT_TIME'] == 'average' ? 'average' : 'total'
  end

  def to_s
    s = "<<< BENCHMARK BEGIN >>>\n\n"
    s << "#{format 'total'}: 100.000% #{format total_time}\n\n"
    times = op_times.values
    if sort_order == 'average'
      times.sort!{|first, second| second.average_time <=> first.average_time }
    else
      times.sort!{|first, second| second.total_time   <=> first.total_time }
    end
    times.unshift loop_time
    times.each do |op_time|
      s << "#{format op_time.name}: #{format_percentage op_time.total_time} #{format op_time.total_time} / #{format op_time.count} = #{format op_time.average_time}\n"
    end
    s << "\n<<< BENCHMARK END   >>>\n"
  end

  def format input
    if input.is_a? String
      "%20.20s" % input
    elsif input.is_a? Float
      "%9i ns" % (input * 1000000000)
    elsif input.is_a? Integer
      "%8i" % input
    end
  end

  def format_percentage time
    ("%3.3f%" % (100 * time / total_time)).rjust(8, ' ')
  end

  def display
    print to_s
  end
end
