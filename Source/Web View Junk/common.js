/* JavaScript used from at least two different places. */

// Assumes Zepto is available.

// Loads FastClick if it's available.
$(function() {
  if (typeof FastClick !== 'undefined') {
    FastClick.attach(document.body);
  }
});

// Starts the WebViewJavascriptBridge.
function startBridge(callback) {
  if (window.WebViewJavascriptBridge) {
    callback(WebViewJavascriptBridge);
  } else {
    document.addEventListener('WebViewJavascriptBridgeReady', function() {
      callback(WebViewJavascriptBridge);
    }, false);
  }
}

// Toggles spoilers on tap.
$(function() {
  $('body').on('click', '.bbc-spoiler', function(event) {
    var target = $(event.target);
    var spoiler = target.closest('.bbc-spoiler');
    var isLink = target.closest('a, [data-awful-linkified-image]').length > 0;
    var isSpoiled = spoiler.hasClass('spoiled');
    if (!(isLink && isSpoiled)) {
      spoiler.toggleClass('spoiled');
    }
    if (isLink && !isSpoiled) {
      event.preventDefault();
    }
  });
});

// Shows linkified images on tap.
$('body').on('click', '[data-awful-linkified-image]', function(event) {
  var link = $(event.target);
  if (link.closest('.bbc-spoiler:not(.spoiled)').length > 0) {
    return;
  }
  showLinkifiedImage(link);
  
  // Don't follow links when showing linkified images.
  event.preventDefault();
});

// Returns the CGRectFromString-formatted bounding rect of an element, for passing back to Objective-C.
function rectOfElement(element) {
  var rect = $(element).offset();
  var origin = [rect.left - window.pageXOffset, rect.top - window.pageYOffset].join(",");
  var size = [rect.width, rect.height].join(",");
  return "{{" + origin + "},{" + size + "}}";
}

// Reveals or hides avatars in each post header.
function showAvatars(show) {
  if (show) {
    $('header[data-awful-avatar]').each(function() {
      var header = $(this);
      var img = $('<img>', {
        src: header.data('awful-avatar'),
        alt: '',
        class: 'avatar'
      });
      img.prependTo(header);
      header.data('avatar', null);
      header.closest('post').removeClass('no-avatar');
    });
  } else {
    $('header img.avatar').each(function() {
      var img = $(this);
      img.closest('header').data('awful-avatar', img.attr('src'));
      img.remove();
      img.closest('post').addClass('no-avatar');
    });
  }
}

// Replaces a linkified image with the image it represents.
function showLinkifiedImage(link) {
  link = $(link);
  link.replaceWith($('<img>', { border: 0, alt: '', src: link.text() }));
}

// Updates (or removes if 100%) the font scale setting.
function fontScale(scalePercentage) {
  var style = $('#awful-font-scale-style');
  if (scalePercentage == 100) {
    style.text('');
  } else {
    style.text(".nameanddate, .postbody, footer { font-size: " + scalePercentage + "%; }");
  }
}

// Returns an object of elements that may warrant further interaction.
//
// The returned object may include keys for:
//   * spoiledImageURL: a string URL pointing to an image.
//   * spoiledLink: an object with keys:
//     * rect: the link element's bounding box.
//     * URL: a string URL the link is pointing to.
//   * spoiledVideo: an object with keys:
//     * rect: the video element's bounding box.
//     * URL: a string URL pointing to the video.
function interestingElementsAtPoint(x, y) {
  var items = {};
  var elementAtPoint = $(document.elementFromPoint(x, y));
  function isSpoiled(element) {
    var spoiler = element.closest('.bbc-spoiler');
    return spoiler.length == 0 || spoiler.hasClass('spoiled');
  }

  var img = elementAtPoint.closest('img');
  if (img.length && isSpoiled(img)) {
    items.spoiledImageURL = img.attr('src');
  }

  var a = elementAtPoint.closest('a');
  if (a.length && isSpoiled(a)) {
    items.spoiledLink = {
      rect: rectOfElement(a),
      URL: a.attr('href')
    };
  }
  
  var iframe = elementAtPoint.closest('iframe');
  if (iframe.length && isSpoiled(iframe)) {
    items.spoiledVideo = {
      rect: rectOfElement(iframe),
      URL: iframe.attr('src')
    };
  };
  
  return items;
}
