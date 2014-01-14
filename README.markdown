FMMoveTable
=======================

FMMoveTable is an UITableView subclass that provides moving rows by simply tap and hold an appropriate row *without* switching the table to its edit mode.

![](http://madefm.com/media/blog/FMMoveTableViewSampleImage.png)

Donations
---------

I wrote FMMoveTable for use in one of my own apps and think that it could be quite useful (and very time-saving) for others. 

If you find it helpful, a Paypal donation would be very appreciated (donation [at] madeFM [dot] com).


How to use
----------

1.	Import the QuartzCore framework.
2.	Add FMMoveTableView.(h/m) and FMMoveTableViewCell.(h/m) to your project
3.	Change you UITableView subclass to be a subclass of *FMMoveTableView*
4.	Change your UITableViewCell subclass to be a subclass of *FMMoveTableViewCell*
5.	Update your UI(Table)ViewController to conform to *FMMoveTableViewDataSource* and (optional) *FMMoveTableViewDelegate*
6.	Implement at least the delegate method `moveTableView:moveRowFromIndexPath:toIndexPath:` to update your model after a move
7.	Implement some additional checked in your table view data source / delegate. Check the *FMMoveViewController* for further details

Background
----------

**FMMoveTableView** 

Addopts the known UITableViewDataSource and UITableViewDelegate methods to check whether a row:

* **Will move:** `moveTableView:willMoveRowAtIndexPath:`
* **Can be moved:** `moveTableView:canMoveRowAtIndexPath:`
* **Can move to an index path:** `moveTableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:`
* **Did move:** `moveTableView:moveRowFromIndexPath:toIndexPath:`


***


**FMMoveTableViewCell** 

Uses a method `prepareForMove` that you may need to overwrite if you use a custom subclass. 

In it's basic implementation it resets the *textLabel*, *detailTextLabel* and *imageView*.



Contact
-------

I can't answer any questions about how to use the code, but I'd love to read any emails telling me that you're using it, creating an app with it, or just saying thanks.

Florian

Twitter: [http://twitter.com/FlorianMielke](http://twitter.com/FlorianMielke)