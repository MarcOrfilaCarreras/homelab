import os, re

if __name__== "__main__":

    input = open('README.md').read()

    folders = [name for name in os.listdir('tasks/services/tasks') if os.path.isdir(os.path.join('tasks/services/tasks', name))]

    html = "<!-- Start Replace -->\n"

    for f in folders:
        html += '    <tr><td><img src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/' + f + '.png" style="height: 25px"></img></td><td>' + f.capitalize() + '</td></tr> \n'
    
    html += "<!-- End Replace -->"

    with open('README.md', 'w') as f:
        f.write(re.sub('<!-- Start Replace -->.*?<!-- End Replace -->', html, input, flags=re.DOTALL))
        f.close
    
