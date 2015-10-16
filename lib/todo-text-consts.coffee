module.exports = todoTextConsts =
  regex:
    h2: /^##\s/
    h3: /^###\s/
    item: /^\s*-\s/
    doneBadge: /DONE/
    day: /\s[MTWRSFU]\s/
    duration: /\d+[mhd]/g
  formats:
    dateformat: 'MMM-Do-YYYY'
    dayKeys:
      M: 'Mo'
      T: 'Tu'
      W: 'We'
      R: 'Th'
      F: 'Fr'
      S: 'Sa'
      U: 'Su'
