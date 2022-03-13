
The following files are needed:
  awthemes.tcl            - main
  colorutils.tcl          - color utilities
  pkgIndex.tcl            - package index
  awarc.tcl               - scalable arc theme
  awblack.tcl             - scalable black theme
  awdark.tcl              - awdark theme
  awlight.tcl             - awlight theme
  awwinxpblue.tcl         - scalable winxpblue theme
  awbreeze.tcl            - scalable breeze theme
  awtemplate.tcl          - example file to start a new theme
  i/                      - images

Demonstration scripts:
  demottk.tcl, demoscaled.tcl

Try:
  # application scaling
  tclsh demottk.tcl winxpblue -fontscale 1.2
  # tk scaling only
  tclsh demottk.tcl winxpblue -ttkscale 2.0
  # user with high dpi, smaller font
  tclsh demottk.tcl winxpblue -ttkscale 2.0 -fontscale 0.7
  # scaled styling
  tclsh demoscaled.tcl winxpblue

9.3.1 (2020-9-17)
   - Remove debug.

9.3 (2020-9-17)
   - Fixed inappropriate toolbutton width setting.

9.2.4 (2020-8-14)
   - remove unneeded options for scrollbar

9.2.3 (2020-7-17)
   - remove focus ring from treeview selection.

9.2.2 (2020-6-6)
   - fix: settextcolors: background color.

9.2.1 (2020-5-20)
   - fix: progressbar: rect, rect-bord border size.

9.2 (2020-4-30)
   - arc: notebook: use roundedtop-dark style.
   - fix: set of background/highlight colors: remove extra adjustment.
   - fix: setBackground() color adjustments.

9.1.1 (2020-4-27)
   - fix package provide statements.

9.1 (2020-4-27)
   - progressbar: rect-bord: fixed sizing.
   - progressbar: rect-bord: removed border on trough.
   - various fixes for all themes.
   - Added 'arc' theme by Sergei Golovan

9.0 (2020-4-23)
   - added 'awtemplate.tcl' as an example to start a new theme.
   - simplified and regularized all images.
   - reworked color settings, made much easier to use.
   - reworked all radiobuttons and checkbuttons.
   - treeview: added selected arrow right and selected arrow down images.
   - arrows: added solid, open triangle styles.
   - progressbar: rounded-line: reduced width (breeze).
   - various fixes and improvements to all themes.
   - fix combobox listbox handler.
   - fix combobox color mappings.

8.1 (2020-4-20)
   - rename all colors names so that they can be grouped properly
   - fix: slider/trough display (padding).
   - fix: incorrect combobox state coloring.
   - fix background changes so that it only modifies the
     properly associated background colors.
   - added helper routine 'setThemeGroupColor'
   - changed 'setHighlightColor' to also change the select background color.

8.0 (2020-4-18)
   - menu radiobuttons and menu checkbuttons are now dynamically generated
     and any corresponding .svg files have been removed.
     This also fixes menu radio/check button sizing issues for themes
     other than awdark and awlight.
   - treeview arrows default to inheriting from standard arrows.
   - The themes have been reworked such that each widget has different
     styles that can be applied.  All widget styles are now found in
     the i/awthemes/ directory, and individual theme directories are no
     longer needed.  A theme's style may be overridden by the user.
   - style: slider/rect-bord: cleaned up some sizing issues
     (awdark/awlight)
   - style: arrow/solid-bg: cleaned up some sizing issues (awdark/awlight)
   - fix: disabled progressbar display.
   - fix: disabled trough display.

7.9 (2020-4-12)
   - winxpblue: fixed minor focus color issues (entry, combobox).
   - fixed incorrect scrollbar background color.
   - button: added state {active focus}.
   - entry: added ability to set graphics.
   - notebook: added hover, disabled graphics.
   - combobox: graphics will be set if entry graphics are present.
   - combobox: readonly graphics will be set to button graphics if
     both entry and button graphics are present (breeze theme).
   - menubutton: option to use button graphics for menubuttons.
   - toolbutton: option to use button graphics for toolbuttons.
   - 'setListBoxColors': remove borderwidth and relief settings.
   - spinbox: graphics will be set if entry graphics are present.
   - internal code cleanup: various theme settings have been renamed.
   - added breeze theme (based on Maximilian Lika's breeze theme 0.8).
   - add new helper routines to ::themeutils to set the background color
     and to set the focus/highlight color.
   - awdark/awlight: no tksvg: Fixed some grip/slider colors.
   - fix user color overrides

7.8 (2020-3-8)
   - fix highlight background/color for text/label widgets.

7.7 (2020-1-17)
   - fix crash when tksvg not present.
   - improve awdark border colors.

7.6 (2019-12-7)
   - better grip design

7.5 (2019-12-4)
   - reworked all .svg files.
   - cleaned up notebook colors.
   - fixed scaling issue with scaled style scaling.
   - fixed combobox scaling.
   - fixed scrollbar arrows.
   - scaled combobox listbox scrollbar.

7.4 (2019-12-3)
   - added hasImage routine for use by checkButtonToggle
   - Fix menu highlight color

7.3 (2019-12-2)
   - fix spinbox scaled styling

7.2 (2019-12-2)
   - setBackground will not do anything if the background color is unchanged.
   - fixed a bug with graphical buttons.
   - make setbackground more robust.

7.1 (2019-12-1)
   - fix border/padding scaling, needed for rounded buttons/tabs.

7.0 (2019-11-30)
   - clean up .svg files to use alpha channel for disabled colors.
   - calculate some disabled colors.
   - fix doc.
   - split out theme specific code into separate files.
   - Fix scaledStyle set of treeview indicator.
   - make the tab topbar a generalized option.
   - merge themeutils package
   - clean up notebook tabs.
   - winxpcblue: notebook tab graphics.
   - winxpcblue: disabled images.
   - black: disabled cb/rb images.
   - black: add labelframe color.
6.0  (2019-11-23)
   - fix !focus colors
   - slider border color
   - various styling fixes and improvements
   - separate scrollbar color
   - optional scrollbar grip
   - button images are now supported
   - added winxpblue scalable theme
   - fixed missing awdark and awlight labelframe

awthemes 5.1 (2019-11-20)
   - add more colors to support differing spinbox and scroll arrow colors.
   - awlight, awdark, black theme cleanup
   - rename menubutton arrow .svg files.
   - menubutton styling fixes

awthemes 5.0
   - rewrite so that the procedures are no longer duplicated.
   - rewrite set of arrow height/width and combobox arrow height.
   - Add scaledStyle procedure to add a scaled style to the theme.
   - Added a user configurable scaling factor.

awthemes 4.2.1
   - fix pkgIndex.tcl to be able to load the themes

awthemes 4.2
   - fix scaling of images.
   - size menu radiobutton and checkbutton images.
   - add support for flexmenu.

awthemes 4.1
   - breaking change: renamed tab.* color names to base.tab.*
   - fix bugs in setBackground and setHighlight caused by the color
       renaming.
   - fix where the hover color for check and radio buttons is set.

awthemes 4.0
   - added support for other clam based themes.
   - breaking change: the .svg files are now loaded from the filesystem
       in order to support multiple themes.
   - breaking change: All of the various colors and derived colors have
       been renamed.
   - awdark/awlight: Fixed empty treeview indicator.
   - added scalable 'black' theme.

awthemes 3.1
  - Added themeutils.tcl.
      ::themeutils::setThemeColors awdark color-name color ...
    allows the colors to be set.  The graphical colors will be
    changed when tksvg is in use.  See themeutils.tcl for a list
    of color names.

awthemes 3.0
  - Breaking change: The package name has been renamed so
    that 'package require awdark' works.

  - Support for tksvg has been added.
    New graphics have been added to support tksvg, and the graphics
    will scale according to the 'tk scaling' setting.

    'tk scaling' must be set prior to the package require statement.

  - demottk.tcl has been updated to have scalable fonts.
    The 'tk scaling' factor may be specified on the command line:
      demottk.tcl <theme> [-scale <tk-scaling>]
