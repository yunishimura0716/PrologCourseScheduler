const fs = require('fs');

// to format JSON from <source-file> to <output prolog file>:
// node format.js <source-file> <output file>

// list of JSON keys:
// 'dept'     
// 'number'   
// 'section'  
// 'status'   
// 'link'     
// 'activity' 
// 'term'     
// 'mode'     
// 'days'     
// 'start'    
// 'end'      
// 'in-person'

(async () => {
  
  const source = (process.argv[2]) ? process.argv[2] : './sections';
  const dest   = (process.argv[2]) ? process.argv[3] : './samplefacts.pl'
  console.log(process.argv, process.argc, source);

  const content = await fs.promises.readFile(source, 'utf8');
  const sections = JSON.parse(content);
  await fs.promises.writeFile(dest, '', 'utf8');
  for (let i = 0; i < sections.length; i++) {
    const section = sections[i];

    Object.keys(section).forEach((key) => {
      section[key] = section[key].toLowerCase()
    });

    const status = (section.status && section.status !== ' ') ? section.status : 'null';
    const status_sp   = ' '.repeat(10 - status.length);

    const activity = (section.activity && section.activity !== ' ') ? (section.activity.replace(/\s/g, '')) : 'null';
    const activity_sp = ' '.repeat(12 - activity.length);

    const section_s = (section.section && section.section.charAt(1) === 'w') ? ('w'+section.section.replace('w', '0')).trim() : section.section
    const section_sp = ' '.repeat(4 - section_s.length);

    const mode = (section.mode && section.mode.trim() === 'in-person') ? 'inperson' : section.mode.trim();
    const mode_sp = ' '.repeat(8 - mode.length);

    const days = `days(${section.days.trim().split(' ').join(', ')})`;
    const days_sp = ' '.repeat(19 - days.length);

    const start_time = `time(${section.start.split(':')[0]}, ${section.start.split(':')[1]})`;
    const end_time = `time(${section.end.split(':')[0]}, ${section.end.split(':')[1]})`;
    const stime_sp = ' '.repeat(12 - start_time.length);
    const etime_sp = ' '.repeat(12 - end_time.length);

    await fs.promises.appendFile(
      dest, 
      `section(` + 
      `${section.dept}, ` +
      `${section.number}, ` + 
      `${section_s},${section_sp} ` +
      `${status},${status_sp} ` + 
      `${activity},${activity_sp} ` + 
      `${section.term}, ` + 
      `${mode},${mode_sp} ` + 
      `${days},${days_sp} ` +
      `${start_time},${stime_sp} ` +
      `${end_time},${etime_sp} ` +
      `${section.in_person}).` + 
      `\n`, 
      'utf8')
  }
})();

