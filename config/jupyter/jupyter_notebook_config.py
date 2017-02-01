import json
import os
import sys
sys.path.append('/root/.jupyter/extensions/')

c.JupyterApp.ip = '*'
c.JupyterApp.port = 80
c.JupyterApp.open_browser = False
c.JupyterApp.allow_credentials = True
c.JupyterApp.nbserver_extensions = ['jupyter_nbgallery.status', 'jupyter_nbgallery.post']
c.JupyterApp.reraise_server_extension_failures = True
c.JupyterApp.extra_static_paths = ['/root/.jupyter/static']
c.JupyterApp.extra_nbextensions_path = ['/root/.jupyter/extensions/']
c.JupyterApp.tornado_settings = {'static_url_prefix': '/Jupyter/static/'}
c.JupyterApp.allow_origin = 'https://nb.gallery'

# needed to receive notebooks from the gallery
c.JupyterApp.disable_check_xsrf = True

# Override gallery location
nbgallery_url = os.getenv('NBGALLERY_URL')
if nbgallery_url:
  print('Setting nbgallery url to %s' % nbgallery_url)
  c.JupyterApp.allow_origin = nbgallery_url
  config = json.loads(open('/root/.jupyter/nbconfig/common.json').read())
  config['nbgallery']['url'] = nbgallery_url
  with open('/root/.jupyter/nbconfig/common.json', 'w') as output:
    output.write(json.dumps(config, indent=2))
