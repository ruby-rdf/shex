require File.join(File.dirname(__FILE__), 'spec_helper')

describe ShEx::VERSION do
  it "should match the VERSION file" do
    expect(ShEx::VERSION.to_s).to eq File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).chomp
  end
end
