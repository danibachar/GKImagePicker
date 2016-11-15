Pod::Spec.new do |s|
  s.name           =  'DBImagePicker'
  s.version        =  '1.2.1'
  s.license        =  'MIT'
  s.platform       =  :ios, '8.0'
  s.summary        =  'Image Picker with support for custom crop areas.'
  s.description    =  'A fork of GKImagePicker (0.0.1) updated for iOS 8, that also takes care of the default sources. Original fork by Ahmed Khalaf, this one fixes an issue with iPhone 6 devices.'
  s.homepage       =  'https://github.com/danibachar/GKImagePicker'
  s.author         =  { 'Daniel Bachar' => 'danibachar89@gmail.com' }
  s.source         =  { :git => 'https://github.com/danibachar/GKImagePicker.git', :tag => '1.2.1' }
  s.resources      =  'GKImages/*.png'
  s.source_files   =  'GKClasses/*.{h,m}'
  s.preserve_paths =  'GKClasses', 'GKImages'
  s.frameworks     =  'UIKit'
  s.requires_arc   =  true
end
