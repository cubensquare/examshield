cat <<EOF > /etc/xdg/menus/applications-merged/blacklist.menu
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
 "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
<Menu>
  <Name>Applications</Name>
  <Exclude>
    <Filename>xfce4-appfinder.desktop</Filename>
    <Filename>xarchiver.desktop</Filename>
    <Filename>mlterm.desktop</Filename>
    <Filename>xterm.desktop</Filename>
    <Filename>mousepad.desktop</Filename>
    <Filename>claws-mail.desktop</Filename>
    <Filename>epiphany.desktop</Filename>
  </Exclude>
</Menu>
EOF
