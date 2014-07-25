class Item < Struct.new(:uid, :arg, :title, :subtitle, :valid); end

class XmlBuilder
  attr_reader :output

  def initialize
    @output = '<?xml version="1.0"?>'
  end

  def self.build(&block)
    builder = new
    yield(builder)
    builder.output
  end

  def items(&block)
    @output << '<items>'
    yield(self)
    @output << '</items>'
  end

  def item(item)
    @output << <<-eos
      <item uid="#{item.uid}" arg="#{item.arg}" valid="#{item.valid}">
        <title>#{item.title}</title>
        <subtitle>#{item.subtitle}</subtitle>
        <icon>icon.png</icon>
      </item>
    eos
  end
end
