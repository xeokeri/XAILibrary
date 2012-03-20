#XAIImageCache (for iOS)

A UIImage caching mechanism, that is configurable. Currently supports flushing of images older than a specified date, defaults to 7 days. With a max concurrence of 10 URL fetches at a time.

###Features:

* Loads images from a URL for UIImageView.
* Checks if image exists in the cache, if cached uses cached image, thus bypassing NSURLConnection altogether.
* If the image isn't cached, pull from the URL.
* Fade in on successful image load.
* Support for image cache flushing based on date stamp. Defaults to 7 days.
* Support for max concurrent connections. Defaults to 10.

###Pending:
* Load image in CGSize cache. Upcoming feature and the primary reason for this code base.
* UIButton.image, placeholder (possibly with spinner.) Upcoming feature and the secondary reason for this code base
* Update for ARC support.
* Add inline documentation to code.

###Instructions:

###UIImageView Category
    - (void)imageWithURL:(NSString *)imageURL;

###Example:
    [cell.thumbnailView imageWithURL:@"http://localhost/path/to/your/image/file.png"];

###Note:
I am currently using this on a UIImageView in a UITableView cell. It can be used on any UIImageView. It will then use NSOperationQueue, NSOperation, and NSURLConnection to fetch the image, then save to cache. If the image already exists in the cache, based on the URL string, it will use that first and bypass the NSOperationQueue completely.

*I have not thoroughly tested all the code for the UIButton category of this, as I won't need to use it until my next project. At which time I'll update that part, and revise the code as needed.*

#XAILogging

I use this logging for a bit of CoreData debugging, as well as any other NSError or NSException console logging.

#Licensing

I don't believe much in license lingo of open source code bases. If you want to use this, use it. If you want to fix bugs. Fix them. If you want to request or add features, be my guest. If the code breaks your app, I'm not at fault. What may work for some, won't work for all cases. If you use it, at least give me credit for something. Though I repeat, if your app breaks, I'm not responsible.

#Versioning Notes

Expect changes that will break from version to version, meaning that what works one day might require major changes in the next version to make it more slim lined, or more robust. If I get bored with how bad I wrote it the first time, I'll completely rewrite it and do something over completely, making the next version better, but barely compatible with the previous version without changing all the init lines in the code that calls my library files. The more I learn, the more I improve. The more I improve, the cleaner and more empowered the code will become.
