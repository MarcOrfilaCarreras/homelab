import requests
import os, re

if __name__== "__main__":
    
    input = open('README.md').read()
        
    folders = [name.replace(".yml", "").capitalize() for name in os.listdir('roles/docker/tasks') if os.path.isfile(os.path.join('roles/docker/tasks', name))]
    folders.remove("Main")

    html = "<!-- Start Replace -->\n"

    for f in folders:
        image_url = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/" + f.lower() + ".png"

        request = requests.get(image_url)

        if request.status_code != 200:
            image_url = "https://static.vecteezy.com/system/resources/previews/019/617/157/original/container-isometric-symbol-png.png"

        html += '    <tr><td><img src="' + image_url + '" style="height: 25px"></img></td><td>' + f.capitalize() + '</td></tr> \n'
    
    html += "<!-- End Replace -->"

    with open('README.md', 'w') as f:
        f.write(re.sub('<!-- Start Replace -->.*?<!-- End Replace -->', html, input, flags=re.DOTALL))
        f.close
    