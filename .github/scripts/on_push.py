import os, re

if __name__== "__main__":
    
    input = open('README.md').read()
        
    folders = [name.replace(".yml", "").capitalize() for name in os.listdir('roles/docker/tasks') if os.path.isfile(os.path.join('roles/docker/tasks', name))]
    folders.remove("Main")

    html = "<!-- Start Replace -->\n"

    for f in folders:
        html += '    <tr><td><img src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/' + f.lower() + '.png" style="height: 25px"></img></td><td>' + f.capitalize() + '</td></tr> \n'
    
    html += "<!-- End Replace -->"

    with open('README.md', 'w') as f:
        f.write(re.sub('<!-- Start Replace -->.*?<!-- End Replace -->', html, input, flags=re.DOTALL))
        f.close
    