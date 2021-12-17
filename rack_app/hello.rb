class Hello
  def self.call(env)
    puts "Timing Start: #{env['Timing-Start']}"
    ['200', {'Content-Type' => 'text/html'}, ['Hello, Rack!']]
  end
end
