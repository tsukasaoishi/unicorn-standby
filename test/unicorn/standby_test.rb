require 'test_helper'
require 'fileutils'
require 'open-uri'

class Unicorn::StandbyTest < Minitest::Test
  class HelloApp
    def call(env)
      [ 200, { 'Content-Type' => 'text/plain' }, [ "Hello\\n" ] ]
    end
  end

  def setup
    @pwd = Dir.pwd
    @tmpfile = Tempfile.new('unicorn_standby_test')
    @tmpdir = @tmpfile.path
    @tmpfile.close!
    Dir.mkdir(@tmpdir)
    Dir.chdir(@tmpdir)
    @addr = "127.0.0.1"
    @port = unused_port
    FileUtils.cp(File.join(File.dirname(__FILE__), "config.ru"), @tmpdir)
    unicorn_config = File.read(File.join(File.dirname(__FILE__), "unicorn_config.rb"))
    File.open(File.join(@tmpdir, "unicorn_config.rb"), "w") {|f| f.write(unicorn_config % [@port]) }
    `unicorn-standby -c unicorn_config.rb -D`
  end

  def teardown
    Process.kill(:QUIT, File.read("unicorn.pid").to_i)
    Dir.chdir(@pwd)
    FileUtils.rmtree(@tmpdir)
  end

  def assert_standby
    ps_list = `ps aux | grep "unicorn-standby master (standby)" | grep -v grep`.split("\n")
    assert_equal 1, ps_list.size

    ps = ps_list.first
    assert_match(/#{Regexp.escape("unicorn-standby master (standby) -c unicorn_config.rb -D")}/, ps)
  end

  test "standby starts" do
    assert_standby
  end

  test "accept the request" do
    res = open("http://#{@addr}:#{@port}").read
    assert_equal "Hello", res

    ps_list = `ps aux | grep unicorn-standby | grep unicorn_config.rb | grep -v grep`.split("\n")
    assert_equal 2, ps_list.size

    ps_list.each do |ps|
      assert_match(/#{Regexp.escape("unicorn-standby ")}(worker\[0\]|master)#{Regexp.escape(" -c unicorn_config.rb -D")}/, ps)
    end
  end

  test "reload unicorn" do
    res = open("http://#{@addr}:#{@port}").read
    assert_equal("Hello", res)

    Process.kill(:USR2, File.read("unicorn.pid").to_i)
    sleep 2
    assert_standby
  end

  private

  def unused_port
    retries = 100
    base = 5000
    port = sock = nil

    begin
      port = base + rand(32768 - base)
      sock = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      sock.bind(Socket.pack_sockaddr_in(port, @addr))
      sock.listen(5)
    rescue Errno::EADDRINUSE, Errno::EACCES
      sock.close rescue nil
      retry if (retries -= 1) >= 0
    end

    sock.close rescue nil
    port
  end
end
