
use ExtUtils::MakeMaker;

WriteMakefile( 
        'VERSION_FROM' => "Simple.pm",
	'NAME'	  => 'Proc::Simple',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	PREREQ_PM => {
	    'Test::More' => 0,
	    'IO::Handle' => 0,
	},
	);
