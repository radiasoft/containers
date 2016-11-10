from dockerspawner import DockerSpawner
from jupyter_client.localinterfaces import public_ips
import base64

c.Authenticator.admin_users = set(['vagrant'])
c.DockerSpawner.http_timeout = 120
c.DockerSpawner.container_image = 'radiasoft/beamsim-jupyter'
c.DockerSpawner.remove_containers = True
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.volumes = {
    '$PWD/run/jupyterhub/{username}': {
        # POSIT: notebook_dir in containers/radiasoft/beamsim-jupyter/build.sh
        'bind': '/home/vagrant/jupyter',
        # NFS is allowed globally the "Z" modifies an selinux context for non-NFS files
    },
    '$PWD/run/scratch/{username}': {
        # POSIT: notebook_dir in containers/radiasoft/beamsim-jupyter/build.sh
        'bind': '/home/vagrant/scratch',
    },
}

c.JupyterHub.authenticator_class = 'jupyterhub.auth.PAMAuthenticator'
c.JupyterHub.confirm_no_ssl = True
c.JupyterHub.cookie_secret = base64.b64decode('qBdGBamOJTk5REgm7GUdsReB4utbp4g+vBja0SwY2IQojyCxA+CwzOV5dTyPJWvK13s61Yie0c/WDUfy8HtU2w==')
# No need to test postgres
#c.JupyterHub.db_url = 'postgresql://jupyterhub:Ydt21HRKO7NnMBIC@postgresql-jupyterhub:5432/jupyterhub'
c.JupyterHub.hub_ip = public_ips()[0]
c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.port = 8000
c.JupyterHub.proxy_auth_token = '+UFr+ALeDDPR4jg0WNX+hgaF0EV5FNat1A3Sv0swbrg='
c.JupyterHub.spawner_class = DockerSpawner

# Debugging only
c.Application.log_level = 'DEBUG'
# Might not want this, but for now it's useful to see everything
#c.JupyterHub.debug_db = True
c.JupyterHub.debug_proxy = True
c.JupyterHub.log_level = 'DEBUG'
c.LocalProcessSpawner.debug = True
c.Spawner.debug = True

# Testing only; Need a passwd for vagrant inside container for PAMAuthenticator
import subprocess
subprocess.check_call('echo vagrant:vagrant|chpasswd', shell=True)
