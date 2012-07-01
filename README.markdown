FMMoveTable
=======================

FMMoveTable is an UITableView subclass that provides moving rows by simply tap and hold an appropriate row *without* switching the table to it's edit mode.

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

Take care. 
Florian

Web: [http://blog.madeFM.com](http://madeFM.com)
Twitter: [http://twitter.com/FlorianMielke](http://twitter.com/FlorianMielke)



License and Warranty
--------------------

Available under the terms of a BSD-style open source license.


Copyright © 2012, Florian Mielke. All rights reserved.


This software is supplied to you by Florian Mielke in consideration of your agreement to the following terms, and your use, installation, modification or redistribution of this software constitutes acceptance of these terms. If you do not agree with these terms, please do not use, install, modify or redistribute this software.

In consideration of your agreement to abide by the following terms, and subject to these terms, Florian Mielke grants you a personal, non-exclusive license, to use, reproduce, modify and redistribute the software, with or without modifications, in source and/or binary forms; provided that if you redistribute the software in its entirety and without modifications, you must retain this notice and the following text and disclaimers in all such redistributions of the software, and that in all cases attribution of Florian Mielke as the original author of the source code shall be included in all such resulting software products or distributions.

Neither the name, trademarks, service marks or logos of Florian Mielke may be used to endorse or promote products derived from the software without specific prior written permission from Florian Mielke. Except as expressly stated in this notice, no other rights or licenses, express or implied, are granted by Florian Mielke herein, including but not limited to any patent rights that may be infringed by your derivative works or by other works in which the software may be incorporated.

The software is provided by Florian Mielke on an "AS IS" basis. FLORIAN MIELKE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL FLORIAN MIELKE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF FLORIAN MIELKE HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.