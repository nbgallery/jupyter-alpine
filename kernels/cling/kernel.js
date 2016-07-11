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
    if (kernels.data['cling'] != 'installed') {
      dialog.modal({
        sanitize: false,
        title: 'Installing Cling ...',
        body: '<br>\
               <div class="progress"> \
                 <div class="progress-bar progress-bar-striped active" role="progressbar" style="width: 100%"> \
                 </div> \
               </div>'
      });

      $([Jupyter.events]).on('kernel_ready.Kernel', function() {
        $('.modal').modal('hide');
        kernels.update({cling: 'installed'});
      });
    }
  });

  kernels.load();

  // original Ruby kernel.js
  var onload = function() {
    Jupyter.CodeCell.options_default['cm_config']['indentUnit'] = 2;
    var cells = Jupyter.notebook.get_cells();
    for (var i in cells) {
      var c = cells[i];
      if (c.cell_type === 'code') {
        c.code_mirror.setOption('indentUnit', 2);
      }
    }
  }
  
  return {onload:onload};
});
