class Item < Struct.new(:uid, :arg, :title, :subtitle, :valid, :icon); end

class XmlBuilder
  attr_reader :output

  def initialize
    @output = '<?xml version="1.0"?>'"\n"
  end

  def self.build(&block)
    builder = new
    yield(builder)
    builder.output
  end

  def items(&block)
    @output << '<items>'"\n"
    yield(self)
    @output << '</items>'
  end

  def item(item)
    @output << <<-eos
      <item uid="#{item.uid}" arg="#{item.arg}" valid="#{item.valid}">
        <title>#{item.title}</title>
        <subtitle>#{item.subtitle}</subtitle>
        <icon>#{item.icon}</icon>
      </item>
    eos
  end
end
