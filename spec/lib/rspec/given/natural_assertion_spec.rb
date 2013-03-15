require 'rspec/given'

# The Faux module defines a FauxThen that is used to setup an
# environment identical to the real Then blocks in order to setup a
# realistic NaturalAssertion object that can be used for making
# assertions.
#
# Typical Usage:
#
#     context "with something" do
#       Given(:a) { 1 }
#       FauxThen { a + 2 }
#       Then { result_block == 3 }
#       Then { na.evaluate("a") == 1 }
#     end
#
# The FauxThen sets up two special values:
#
# * result_block -- is the result of evaluating the FauxThen block
# * na -- is a the natural assertion object whose context is the
#         FauxThen block.
#
module Faux
  module CX
    def FauxThen(&block)
      @block = block
    end
    def the_block
      @block
    end
  end

  module IX
    def block_result
      instance_eval(&self.class.the_block)
    end

    def na
      block = self.class.the_block
      nassert = RSpec::Given::NaturalAssertion.new("FauxThen", block, self, self.class._rgc_lines)
    end
  end
end

# Extend RSpec with our Faux Then blocks
RSpec.configure do |c|
  c.extend(Faux::CX)
  c.include(Faux::IX)
end

describe "Environmental Access" do
  use_natural_assertions

  X = 1
  Given(:a) { 2 }
  FauxThen { X + a }

  Then { block_result == 3 }
  Then { na.evaluate("X") == 1 }
  Then { na.evaluate("a") == 2 }
  Then { na.evaluate("X+a") == 3 }
end

module Nested
  X = 1
  describe "Environmental Access with Nested modules" do
    use_natural_assertions
    Given(:a) { 2 }
    FauxThen { X + a }
    Then { block_result == 3 }
    Then { na.evaluate("a") == 2 }
    Then { na.evaluate("X") == 1 }
    Then { na.evaluate("a+X") == 3 }
  end
end

describe RSpec::Given::NaturalAssertion do
  before do
    pending "Natural Assertions disabled for JRuby" unless RSpec::Given::NATURAL_ASSERTIONS_SUPPORTED
  end

  describe "#content?" do
    context "with empty block" do
      FauxThen { }
      Then { na.should_not have_content }
    end
    context "with block returning false" do
      FauxThen { false }
      Then { na.should have_content }
    end
  end

  describe "detecting RSpec Assertions" do
    context "with should" do
      FauxThen { a.should == 1 }
      Then { na.should be_using_rspec_assertion }
    end

    context "with should_not" do
      FauxThen { a.should_not == 1 }
      Then { na.should be_using_rspec_assertion }
    end

    context "with expect/to" do
      FauxThen { expect(a).to eq(1) }
      Then { na.should be_using_rspec_assertion }
    end

    context "with expect/not_to" do
      FauxThen { expect(a).not_to eq(1) }
      Then { na.should be_using_rspec_assertion }
    end

    context "with expect and block" do
      FauxThen { expect { a }.to eq(1) }
      Then { na.should be_using_rspec_assertion }
    end

    context "with natural assertion" do
      FauxThen { a == 1 }
      Then { na.should_not be_using_rspec_assertion }
    end
  end

  describe "failure messages" do
    let(:msg) { na.message }
    Invariant { msg.should =~ /^FauxThen expression/ }

    context "with equals assertion" do
      Given(:a) { 1 }
      FauxThen { a == 2 }
      Then { msg.should =~ /\bexpected: +1\b/ }
      Then { msg.should =~ /\bto equal: +2\b/ }
      Then { msg.should =~ /\bfalse +<- +a == 2\b/ }
      Then { msg.should =~ /\b1 +<- +a\b/ }
    end

    context "with equals assertion with do/end" do
      Given(:a) { 1 }
      FauxThen do a == 2 end
      Then { msg.should =~ /\bexpected: +1\b/ }
      Then { msg.should =~ /\bto equal: +2\b/ }
      Then { msg.should =~ /\bfalse +<- +a == 2\b/ }
      Then { msg.should =~ /\b1 +<- +a\b/ }
    end

    context "with not-equals assertion" do
      Given(:a) { 1 }
      FauxThen { a != 1 }
      Then { msg.should =~ /\bexpected: +1\b/ }
      Then { msg.should =~ /\bto not equal: +1\b/ }
      Then { msg.should =~ /\bfalse +<- +a != 1\b/ }
      Then { msg.should =~ /\b1 +<- +a\b/ }
    end

    context "with less than assertion" do
      Given(:a) { 1 }
      FauxThen { a < 1 }
      Then { msg.should =~ /\bexpected: +1\b/ }
      Then { msg.should =~ /\bto be less than: +1\b/ }
      Then { msg.should =~ /\bfalse +<- +a < 1\b/ }
      Then { msg.should =~ /\b1 +<- +a\b/ }
    end

    context "with less than or equal to assertion" do
      Given(:a) { 1 }
      FauxThen { a <= 0 }
      Then { msg.should =~ /\bexpected: +1\b/ }
      Then { msg.should =~ /\bto be less or equal to: +0\b/ }
      Then { msg.should =~ /\bfalse +<- +a <= 0\b/ }
      Then { msg.should =~ /\b1 +<- +a\b/ }
    end

    context "with greater than assertion" do
      Given(:a) { 1 }
      FauxThen { a > 1 }
      Then { msg.should =~ /\bexpected: +1\b/ }
      Then { msg.should =~ /\bto be greater than: +1\b/ }
      Then { msg.should =~ /\bfalse +<- +a > 1\b/ }
      Then { msg.should =~ /\b1 +<- +a\b/ }
    end

    context "with greater than or equal to assertion" do
      Given(:a) { 1 }
      FauxThen { a >= 3 }
      Then { msg.should =~ /\bexpected: +1\b/ }
      Then { msg.should =~ /\bto be greater or equal to: +3\b/ }
      Then { msg.should =~ /\bfalse +<- +a >= 3\b/ }
      Then { msg.should =~ /\b1 +<- +a\b/ }
    end

    context "with match assertion" do
      Given(:s) { "Hello" }
      FauxThen { s =~ /HI/ }
      Then { msg.should =~ /\bexpected: +"Hello"$/ }
      Then { msg.should =~ /\bto match: +\/HI\/$/ }
      Then { msg.should =~ /\bnil +<- +s =~ \/HI\/$/ }
      Then { msg.should =~ /"Hello" +<- +s$/ }
    end

    context "with not match assertion" do
      Given(:s) { "Hello" }
      FauxThen { s !~ /Hello/ }
      Then { msg.should =~ /\bexpected: +"Hello"$/ }
      Then { msg.should =~ /\bto not match: +\/Hello\/$/ }
      Then { msg.should =~ /\bfalse +<- +s !~ \/Hello\/$/ }
      Then { msg.should =~ /"Hello" +<- +s$/ }
    end

    context "with exception" do
      Given(:ary) { nil }
      FauxThen { ary[1] == 3 }
      Then { msg.should =~ /\bexpected: +NoMethodError/ }
      Then { msg.should =~ /\bto equal: +3$/ }
      Then { msg.should =~ /\bNoMethodError.+NilClass\n +<- +ary\[1\] == 3$/ }
      Then { msg.should =~ /\bNoMethodError.+NilClass\n +<- +ary\[1\]$/ }
      Then { msg.should =~ /\bnil +<- +ary$/ }
    end
  end

  describe "bad Then blocks" do
    context "with no statements" do
      FauxThen {  }
      When(:result) { na.message }
      Then { result.should_not have_failed(RSpec::Given::InvalidThenError) }
    end

    context "with multiple statements" do
      FauxThen {
        ary = nil
        ary[1] == 3
      }
      When(:result) { na.message }
      Then { result.should have_failed(RSpec::Given::InvalidThenError, /multiple.*statements/i) }
    end

  end
end
