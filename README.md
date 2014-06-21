#XAIImageCache (for iOS)

A UIImage caching mechanism, that is configurable. Currently supports flushing of images older than a specified date, defaults to 7 days.

###Features:

* Loads images from a URL for UIImageView.
* Checks if image exists in the cache, if cached uses cached image, thus bypassing NSURLConnection altogether.
* If the image isn't cached, pull from the URL.
* Fade in on successful image load.
* Support for image cache flushing based on date stamp. Defaults to 7 days.

###Pending:
* Add inline documentation to code.

###Instructions:

***UIImageView Category***

    - (void)imageWithURL:(NSString *)imageURL;

***Example***

    [cell.thumbnailView imageWithURL:@"http://localhost/path/to/your/image/file.png"];

***UIScrollView Category***

    - (void)imageWithURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath delegate:(id <XAIImageCacheDelegate>)incomingDelegate;

    - (void)imageWithURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath delegate:(id <XAIImageCacheDelegate>)incomingDelegate size:(CGSize)imageSize;

***Example***

    [aScrollView imageWithURL:@"http://localhost/path/to/your/image/file.png" atIndexPath:anIndexPath delegate:aDelegate size:aSize];

###Note:
I am currently using this on a UIImageView in a UITableView cell, as well as using the delegate protocols connected to a UITableViewController and UICollectionView. It can be used on any UIImageView. It will then use NSOperationQueue, NSOperation, and NSURLConnection to fetch the image, then save to cache. If the image already exists in the cache, based on the URL string, it will use that first. It will then check to see if a modified file exists on the server. If a newer image exists, it will then download the new image. The updated image will refresh the storaged cache and the memory cache. Then it will pass back to the delegate and be able to refresh the image that is displaying.

#XAIDataStorage

Core Data library for multithreaded merging, fetching, and more. With notification support.


#XAISQLiteStorage

SQLite3 library for fetching, updating, inserting, and deleting records.

#XAILogging

I use this logging for a bit of CoreData debugging, as well as any other NSError or NSException console logging.

#Licensing

I don't believe much in license lingo of open source code bases. If you want to use this, use it. If you want to fix bugs. Fix them. If you want to request or add features, be my guest. If the code breaks your app, I'm not at fault. What may work for some, won't work for all cases. If you use it, at least give me credit for something. Though I repeat, if your app breaks, I'm not responsible.

#Requirements

Minimum verison of iOS 6, with the intention of switching to NSURLSession which will require iOS 7 or higher.

#Versioning Notes

Expect changes that will break from version to version, meaning that what works one day might require major changes in the next version to make it more slim lined, or more robust. If I get bored with how bad I wrote it the first time, I'll completely rewrite it and do something over completely, making the next version better, but barely compatible with the previous version without changing all the init lines in the code that calls my library files. The more I learn, the more I improve. The more I improve, the cleaner and more empowered the code will become.
