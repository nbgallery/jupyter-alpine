define([
  'base/js/namespace', 
  'base/js/dialog', 
  'services/config',
  'base/js/utils'
], function(
  Jupyter, 
  dialog, 
  config,
  utils
) {
  "use strict";    

  var kernels = new config.ConfigSection('kernels', {
    base_url: utils.get_body_data("baseUrl")
  }); 

  kernels.loaded.then(function() {
    if (kernels.data['pig'] != 'installed') {
      dialog.modal({
        sanitize: false,
        title: 'Installing Pig ...',
        body: '<br>\
               <div class="progress"> \
                 <div class="progress-bar progress-bar-striped active" role="progressbar" style="width: 100%"> \
                 </div> \
               </div>'
      });

      $([Jupyter.events]).on('kernel_ready.Kernel', function() {
        $('.modal').modal('hide');
        kernels.update({pig: 'installed'});
      });
    }
  });

  kernels.load();

  return {onload:onload};
});
