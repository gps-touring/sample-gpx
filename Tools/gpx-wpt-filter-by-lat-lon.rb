require 'nokogiri'

# Reads GPX file passed into stdin.

# ARGUMENTS:
# 1. Min/max latitudes, separated by a comma (no spaces)
# 2. Min/max longitudes, separated by a comma (no spaces)

# RESULT:
# Filteres GPX file will be written to stdout (containing only <wpt> elements)

# Example usage:
#     ruby <this_file.rb> 48.5,48.8 -3.3,-4.1

($lat_min, $lat_max) = ARGV[0].split(",").map{|x| x.to_f}.sort
($lon_min, $lon_max) = ARGV[1].split(",").map{|x| x.to_f}.sort

$stderr.puts "Filtering for waypoints within the following bounding box"
$stderr.puts "Latitude: [#{$lat_min}, #{$lat_max}]"
$stderr.puts "Longitude: [#{$lon_min}, #{$lon_max}]"

# Function for generating xml (used here for html).
def xml(ele, attr = {})
  "<#{ele}#{attr.keys.map{|k| " #{k}=\"#{attr[k]}\""}.join}>" + # Element opening tag with attributes.
    (block_given? ? yield : "") +       # Element contents.
    "</#{ele}>" # Element closing tag.
end

total_in = 0
total_out = 0
doc = Nokogiri::XML($stdin.read)
puts "<?xml version=\"1.0\"?>"
puts xml(:gpx, 
	 creator: "Matt Wallis",
	 version: "1.1",
	 xmlns: "http://www.topografix.com/GPX/1/1",
	 "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
	 "xsi:schemaLocation" => "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd") {
  "\n" +
  doc.css("wpt").select {|x|
    total_in += 1
    lat = x.attributes["lat"].value.to_f
    lon = x.attributes["lon"].value.to_f
    $lat_min <= lat && lat <= $lat_max && $lon_min <= lon && lon <= $lon_max
  }
  .map {|x| 
    total_out += 1
    #x["foo"] = "bar"
    #foo = Nokogiri::XML::Text.new("bar", doc)
    #x.add_child(foo)
    #x.add_child("<foo>bar</foo>")
    sym = x.at_css("sym") 
    if sym
      #$stderr.puts "Yeah #{x.css("sym").size}" 
      sym.content = "Tent"
    else
      x.add_child(xml(:sym) {"Tent"})
    end
    x.to_xml + "\n"	# Use Nokogiri to convert the Node back to XML
  }.join
}
$stderr.puts "Waypoints input: #{total_in}, output: #{total_out}"
