require 'spec_helper'

describe "ruby" do
  let(:vim) { VIM }
  let(:filename) { 'test.rb' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

  specify "if-clauses" do
    set_file_contents <<-EOF
      return "the answer" if 6 * 9 == 42
    EOF

    split

    assert_file_contents <<-EOF
      if 6 * 9 == 42
        return "the answer"
      end
    EOF

    vim.search 'if'
    join

    assert_file_contents <<-EOF
      return "the answer" if 6 * 9 == 42
    EOF
  end

  specify "hashes" do
    set_file_contents <<-EOF
      foo = { :bar => 'baz', :one => 'two' }
    EOF

    vim.search ':bar'
    split

    assert_file_contents <<-EOF
      foo = {
        :bar => 'baz',
        :one => 'two'
      }
    EOF

    vim.search 'foo'
    join

    assert_file_contents <<-EOF
      foo = { :bar => 'baz', :one => 'two' }
    EOF
  end

  # TODO (2012-05-24) Indentation breaks the "end" matching logic
  specify "caching constructs" do
    set_file_contents <<-EOF
      @two ||= 1 + 1
    EOF

    split

    assert_file_contents <<-EOF
      @two ||= begin
                 1 + 1
               end
    EOF

    join

    assert_file_contents <<-EOF
      @two ||= 1 + 1
    EOF
  end

  specify "blocks" do
    set_file_contents <<-EOF
      Bar.new { |b| puts b.to_s }
    EOF

    split

    assert_file_contents <<-EOF
      Bar.new do |b|
        puts b.to_s
      end
    EOF

    join

    assert_file_contents <<-EOF
      Bar.new { |b| puts b.to_s }
    EOF
  end

  specify "method continuations" do
    set_file_contents <<-EOF
      one.
        two.
        three
    EOF

    join

    assert_file_contents <<-EOF
      one.two.three
    EOF
  end

  describe "heredocs" do
    it "joins heredocs into single-quoted strings when possible" do
      set_file_contents <<-EOF
        string = <<-ANYTHING
          something, "anything"
        ANYTHING
      EOF

      VIM.search 'ANYTHING'
      join

      assert_file_contents <<-EOF
        string = 'something, "anything"'
      EOF
    end

    it "joins heredocs into double-quoted strings when there's a single-quoted string inside" do
      set_file_contents <<-EOF
        string = <<-ANYTHING
          something, 'anything'
        ANYTHING
      EOF

      VIM.search 'ANYTHING'
      join

      assert_file_contents <<-EOF
        string = "something, 'anything'"
      EOF
    end

    it "joins heredocs into double-quoted strings when there's interpolation inside" do
      set_file_contents <<-EOF
        string = <<-ANYTHING
          something, \#{anything}
        ANYTHING
      EOF

      VIM.search 'ANYTHING'
      join

      assert_file_contents <<-EOF
        string = "something, \#{anything}"
      EOF
    end

    xit "splits normal strings into heredocs" do
      set_file_contents 'string = "\'something\', \"anything\""'

      VIM.search 'something'
      split

      assert_file_contents <<-OUTER
        string = <<-EOF
          'something', "anything"
        EOF
      OUTER
    end
  end

  describe "method options" do
    specify "with curly braces" do
      VIM.command('let g:splitjoin_ruby_curly_braces = 1')

      set_file_contents <<-EOF
        foo 1, 2, :one => 1, :two => 2
      EOF

      split

      assert_file_contents <<-EOF
        foo 1, 2, {
          :one => 1,
          :two => 2
        }
      EOF

      join

      assert_file_contents <<-EOF
        foo 1, 2, { :one => 1, :two => 2 }
      EOF
    end

    specify "without curly braces" do
      VIM.command('let g:splitjoin_ruby_curly_braces = 0')

      set_file_contents <<-EOF
        foo 1, 2, :one => 1, :two => 2
      EOF

      split

      assert_file_contents <<-EOF
        foo 1, 2,
          :one => 1,
          :two => 2
      EOF

      join

      assert_file_contents <<-EOF
        foo 1, 2, :one => 1, :two => 2
      EOF
    end

    specify "with round braces" do
      VIM.command('let g:splitjoin_ruby_curly_braces = 0')

      set_file_contents <<-EOF
        foo(:one => 1, :two => 2)
      EOF

      split

      assert_file_contents <<-EOF
        foo(
          :one => 1,
          :two => 2
        )
      EOF

      join

      assert_file_contents <<-EOF
        foo(:one => 1, :two => 2)
      EOF
    end
  end
end