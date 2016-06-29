module SwapOutput
  module_function

  STDOUT_LOG_PATH = File.expand_path('../../../log/stdout.log', __FILE__)
  STDERR_LOG_PATH = File.expand_path('../../../log/stderr.log', __FILE__)

  def stdout
    $stdout, backup = open(STDOUT_LOG_PATH, 'a'), $stdout
    begin
      yield
    ensure
      $stdout = backup
    end
  end

  def stderr
    $stderr, backup = open(STDERR_LOG_PATH, 'a'), $stderr
    begin
      yield
    ensure
      $stderr = backup
    end
  end
end
