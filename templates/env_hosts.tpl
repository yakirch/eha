[server_nginx]
${server_nginx_1}
${server_nginx_2}

[server_app]
${server_app_1}
${server_app_2}

[all_units:children]
server_nginx
server_app

[all_units:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=python3
