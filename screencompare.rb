#!/usr/bin/env ruby

require 'selenium-webdriver'
require 'chunky_png'

include ChunkyPNG::Color

#######################################
## Log in and take a picture
#######################################
driver = Selenium::WebDriver.for :firefox
driver.navigate.to "https://mclasshome.com"

element = driver.find_element(:id, 'login-username')
element.send_keys "ope_demo"
element = driver.find_element(:name, 'password')
element.send_keys "1234"
element.submit

driver.save_screenshot('mclasshome.png')

driver.quit

#http://jeffkreeftmeijer.com/2011/comparing-images-and-creating-image-diffs/
#######################################
## Compare pictures exactly
####################################### 
images = [
	ChunkyPNG::Image.from_file('mclasshome_old.png'),
	ChunkyPNG::Image.from_file('mclasshome.png')
]
 
diff = []
 
images.first.height.times do |y|
	images.first.row(y).each_with_index do |pixel, x|
		diff << [x,y] unless pixel == images.last[x,y]
	end
end
 
puts "pixels (total): #{images.first.pixels.length}"
puts "pixels changed: #{diff.length}"
puts "pixels changed (%): #{(diff.length.to_f / images.first.pixels.length) * 100}%"
 
x, y = diff.map{ |xy| xy[0] }, diff.map{ |xy| xy[1] }
 
if diff.length > 0
	images.last.rect(x.min, y.min, x.max, y.max, ChunkyPNG::Color.rgb(0,255,0))
	images.last.save('mclasshome_diff_exact.png') 
end


#######################################
## Compare pictures considering color delta
####################################### 
output = ChunkyPNG::Image.new(images.first.width, images.last.width, WHITE)

diff = []

images.first.height.times do |y|
  images.first.row(y).each_with_index do |pixel, x|
    unless pixel == images.last[x,y]
      score = Math.sqrt(
        (r(images.last[x,y]) - r(pixel)) ** 2 +
        (g(images.last[x,y]) - g(pixel)) ** 2 +
        (b(images.last[x,y]) - b(pixel)) ** 2
      ) / Math.sqrt(MAX ** 2 * 3)

      output[x,y] = grayscale(MAX - (score * MAX).round)
      diff << score
    end
  end
end

puts "pixels (total):     #{images.first.pixels.length}"
puts "pixels changed:     #{diff.length}"
puts "image changed (%): #{(diff.inject {|sum, value| sum + value} / images.first.pixels.length) * 100}%"

if diff.length > 0
	output.save('mclasshome_diff_color.png')
end



#######################################
## Compare pictures invert diff
####################################### 
images.first.height.times do |y|
  images.first.row(y).each_with_index do |pixel, x|

    images.last[x,y] = rgb(
      r(pixel) + r(images.last[x,y]) - 2 * [r(pixel), r(images.last[x,y])].min,
      g(pixel) + g(images.last[x,y]) - 2 * [g(pixel), g(images.last[x,y])].min,
      b(pixel) + b(images.last[x,y]) - 2 * [b(pixel), b(images.last[x,y])].min
    )
  end

end

images.last.save('mclasshome_diff_invert.png')



