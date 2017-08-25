var TW = TW || {};
TW.views = TW.views || {};
TW.views.shared = TW.views.shared || {};
TW.views.shared.gis = TW.views.shared.gis || {};
TW.views.shared.gis.simple_map = TW.views.shared.gis.simple_map || {};

Object.assign(TW.views.shared.gis.simple_map, {

  init: function() {
    // TODO: To be filled in later.
    // intended for use to display on a map objects which know how to GeoJSON themselves
    var simple_map_shell = $('#_simple_map_outer');
    if (simple_map_shell.length) {
      simple_map_shell.removeAttr('hidden');
      var newfcdata = $("#_simple_map_form");
      var fcdata = newfcdata.data('feature-collection');
      var map_canvas = newfcdata.data('map-canvas');
      var map_center = newfcdata.data('map-center');
      var simple_map = TW.vendor.lib.google.maps.initializeMap(map_canvas, fcdata);
    }
  }
});

$(document).on('turbolinks:load', function() {
  var _simple_maps = TW.views.shared.gis.simple_map.init();
});

