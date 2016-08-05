var exec = require('cordova/exec');

var cameraRoll = {};

cameraRoll.getPhotos = function(successCallback, errorCallback, options) {

  options = options || {};

  var width = options.width ? options.width : 0,
      height = options.height ? options.height : 0,

      limit = options.limit ? options.limit : 0,
      offset = options.offset ? options.offset : 0;

  exec(successCallback, errorCallback, "CameraRoll", "getPhotos", [width, height, limit, offset]);
};

cameraRoll.getPhotoByLocalIdentifier = function(identifier, successCallback, errorCallback, options) {

  options = options || {};

  var width = options.width ? options.width : 0,
      height = options.height ? options.height : 0;

  exec(successCallback, errorCallback, "CameraRoll", "getPhotoByLocalIdentifier", [width, height, identifier]);

}

cameraRoll.saveToCameraRoll = function(imageBase64, successCallback, errorCallback, options) {
  exec(successCallback, errorCallback, "CameraRoll", "saveToCameraRoll", [imageBase64]);
};

module.exports = cameraRoll;
