Pod::Spec.new do |s|
    s.name             = "SwiftPrayTimes"
    s.version          = "1.3.3"
    s.summary          = "Pray Times provides a set of handy functions to calculate prayer times for any location around the world"
    s.description      = <<-DESC
                            Pray Times provides a set of handy functions to calculate prayer times for any location around the world,
                            based on a variety of calculation methods currently used in Muslim communities.

                            The code is originally written in JavaScript from http://praytimes.org and translated to Swift.
                            Pray Times is an Islamic project aimed at providing an open-source library for calculating Muslim prayers times.
                            The first version of Pray Times was released in early 2007. The code is currently used in a wide range of Islamic websites and applications.
                       DESC
    s.homepage         = "https://github.com/ZamzamInc/SwiftPrayTimes"
    # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
    s.license          = 'MIT'
    s.author           = { "Zamzam Inc." => "contact@zamzam.io" }
    s.source           = { :git => "https://github.com/ZamzamInc/SwiftPrayTimes.git", :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/zamzaminc'

    s.ios.deployment_target = "8.4"
    s.watchos.deployment_target = "2.0"
    s.tvos.deployment_target = "9.0"

    s.requires_arc = true

    s.source_files = "Source/**/*.{h,swift}"
end
