#!/usr/bin/perl
#
# Dreamcast FMV Auto-Subber v1.6
# A utility to batch re-encode Dreamcast SFD videos with baked-in subtitles.
#
# Written by Derek Pascarella (ateam)

# Modules.
use strict;
use File::Copy;

# Set version number.
my $version = "1.6";

# Set header used in CLI messages.
my $cli_header = "\nDreamcast FMV Auto-Subber v" . $version . "\nA utility to batch re-encode Dreamcast SFD videos with baked-in subtitles.\n\nWritten by Derek Pascarella (ateam)\n\n";

# Check for existence of helper utilities.
my @helper_utilities =
(
	"adxencd.exe",
	"demux.exe",
	"ffmpeg.exe",
	"legaladx.exe",
	"Sfdmux.dll",
	"sfdmux.exe"
);

# Perform helper utility check.
foreach my $file (@helper_utilities)
{
	# Terminate program if missing.
	if(!-e "helper_utilities/" . $file)
	{
		print $cli_header;
		print STDERR "One or more files is missing from the \"helper_utilities\" folder: " . $file;
		print "\n\nPress Enter to exit.\n";
		<STDIN>;
		
		exit;
	}
}

# Throw error if configuration INI doesn't exist.
if(!-e "config.ini")
{
	print $cli_header;
	print STDERR "Configuration file \"config.ini\" missing from root folder.";
	print "\n\nPress Enter to exit.\n";
	<STDIN>;
	
	exit;
}

# Store hash of configuration options from INI.
my %config_options = read_ini("config.ini");

# Perform configuration INI validation.
my($valid_ini, $ini_error_message) = validate_ini(%config_options);

# Throw error if configuration INI contains invalid or missing options.
if(!$valid_ini)
{
	print $cli_header;
	print STDERR $ini_error_message;
	print "\n\nPress Enter to exit.\n";
	<STDIN>;
	
	exit; 
}

# Read contents of "input" folder and store each SFD file name in element of array.
opendir(my $dh, "input");
my @input_files = grep { /\.sfd$/i && -f "input/" . $_ } readdir($dh);
closedir($dh);

# Throw error if no SFD files found in "input" folder.
if(!@input_files)
{
	print $cli_header;
	print STDERR "No SFD files found in \"input\" folder.";
	print "\n\nPress Enter to exit.\n";
	<STDIN>;
	
	exit; 
}

# Status message.
print $cli_header;

# Status message.
print scalar(@input_files) . " video(s) found in \"input\" folder.\n\n";

# Copy each helper utility to "input" folder.
foreach my $file (@helper_utilities)
{
	copy("helper_utilities/" . $file, "input");
}

# Change to "input" folder.
chdir("input");

# Iterate through and process each file.
foreach my $file_sfd (@input_files)
{
	# Status message.
	print "-> " . $file_sfd . "\n";

	# Replace file extension for to generate SRT subtitle file name.
	my $file_srt = $file_sfd =~ s/\.[^.]+$/.SRT/r;

	# Replace file extension for to generate ASS subtitle file name.
	my $file_ass = $file_sfd =~ s/\.[^.]+$/.ASS/r;

	# No accompanying SRT or ASS subtitle file found.
	if(!-e $file_srt && !-e $file_ass)
	{
		print "   - Accompanying subtitle file \"" . $file_srt . "\" or \"" . $file_ass . "\" not found, skipping.\n";
	}
	# Otherwise, continue processing video.
	else
	{
		# Set subtitle format based on detected format.
		my $sub_format;

		if(-e $file_srt && -e $file_ass)
		{
			# Status message.
			print "   - Both SRT and ASS subtitle files detected. Defaulting to ASS.\n";

			$sub_format = "ass";
		}
		elsif(-e $file_srt)
		{
			# Status message.
			print "   - SRT subtitle file detected.\n";

			$sub_format = "srt";
		}
		elsif(-e $file_ass)
		{
			# Status message.
			print "   - ASS subtitle file detected.\n";

			$sub_format = "ass";
		}

		# Parse video dimensions.
		my ($dimensions) = `ffmpeg.exe -i $file_sfd 2>&1 | findstr /r /c:\"Stream.*Video:.* [0-9][0-9]*x[0-9][0-9]*\"` =~ /\b(\d+x\d+)\b/;

		# Status message.
		print "   - Constructing ffmpeg command...\n";

		# Begin constructing ffmpeg command.
		my $ffmpeg_command =  "ffmpeg.exe -i m2v.m2v -vcodec mpeg1video ";
		   $ffmpeg_command .= "-b:v " . $config_options{'bitrate'} . " -maxrate " . $config_options{'bitrate'} . " -minrate " . $config_options{'bitrate'} . " -bufsize " . $config_options{'bitrate'} . " -muxrate " . $config_options{'bitrate'} . " ";
		   $ffmpeg_command .= "-s " . $dimensions . " -an -vf \"subtitles=";

		# Store target aspect ratio width and height from configuration option.
		my($ar_width, $ar_height) = split(/:/, $config_options{'aspect_ratio'});

		# Subtitles are in SRT format.
		if($sub_format eq "srt")
		{			
			# Calculate subtitle scaling.
			my ($width, $height) = $dimensions =~ /^(\d+)x(\d+)$/;
			my $ideal_width_for_height = $height * ($ar_width / $ar_height);
			my $subtitle_scale = sprintf("%.3f", $width / $ideal_width_for_height);

			# Status message.
			print "   - Subtitle horizontal scaling factor " . $subtitle_scale . " calculated for " . $config_options{'aspect_ratio'} . " aspect ratio.\n";

			# Continue constructing ffmpeg command.
			$ffmpeg_command .= $file_srt . ":force_style='Fontname=" . $config_options{'font_face'} . ",Fontsize=" . $config_options{'font_size'} . ",Bold=";

			# Set bold text.
			if($config_options{'font_bold'} eq "yes")
			{
				$ffmpeg_command .= "1";
			}
			# Set regular text.
			else
			{
				$ffmpeg_command .= "0";
			}

			# Continue constructing ffmpeg command.
			$ffmpeg_command .= ",PrimaryColour=&H" . $config_options{'font_color'} . "&,OutlineColour=&H" . $config_options{'outline_color'} . "&,Outline=" . $config_options{'outline_strength'} . ",MarginV=" . $config_options{'margin_vertical'} . ",MarginL=" . $config_options{'margin_left'} . ",MarginR=" . $config_options{'margin_right'} .= ",ScaleX=" . $subtitle_scale . "'\"";
		}
		# Subtitles are in ASS format.
		elsif($sub_format eq "ass")
		{
			# Calculate subtitle scaling.
			my $subtitle_scale = int(($ar_width / $ar_height) * 480 + 0.5) . "x480";

			# Status message.
			print "   - Subtitle scaling at " . $subtitle_scale . " used for " . $config_options{'aspect_ratio'} . " aspect ratio.\n";

			# Continue constructing ffmpeg command.
			$ffmpeg_command .= $file_ass . ":original_size=" . $subtitle_scale . "\"";
		}

		# Finish constructing ffmpeg command.
		$ffmpeg_command .= " m1v.m1v";

		# Status message.
		print "   - Demuxing original SFD...\n";
		
		# Demux SFD.
		system "demux.exe $file_sfd demux > NUL 2>&1";

		# An error occurred when attempting to demux SFD.
		if(!-e "demux_c0.m2a" || !-e "demux_e0.m2v")
		{
			print STDERR "     ERROR: Could not successfully demux audio and video stream!\n";
			print "            Skipping...\n";
		}
		# Otherwise, proceed.
		else
		{
			# Rename audio and video streams.
			rename("demux_c0.m2a", "m2a.m2a");
			rename("demux_e0.m2v", "m2v.m2v");

			# Status message.
			print "   - Converting audio stream to WAV...\n";

			# Convert M2A to WAV.
			system "ffmpeg.exe -i m2a.m2a -c:a pcm_s16le -ar 44100 -ac 2 wav.wav > NUL 2>&1";
			unlink("m2a.m2a");

			# Status message.
			print "   - Converting WAV to SFA...\n";

			# Convert WAV to SFA.
			system "adxencd.exe wav.wav adx.adx > NUL 2>&1";
			unlink("wav.wav");
			system "legaladx.exe adx.adx sfa.sfa > NUL 2>&1";
			unlink("adx.adx");

			# Status message.
			print "   - Encoding new video with subtitles...\n";

			# Encode new video with baked-in subtitles.
			system "$ffmpeg_command > NUL 2>&1";
			unlink("m2v.m2v");

			# Status message.
			print "   - Remuxing new video with original audio stream...\n";
			
			# Remux video and original audio stream.
			system "sfdmux.exe -V=m1v.m1v -A=sfa.sfa -S=sfd.sfd > NUL 2>&1";
			unlink("sfa.sfa");
			unlink("m1v.m1v");

			# Status message.
			print "   - Moving new SFD to \"output\" folder...\n";

			# Move new SFD to "output" folder.
			rename("sfd.sfd", "../output/" . $file_sfd);
		}
	}
}

# Return back to root folder.
chdir("..");

# Delete each helper utility from "input" folder.
foreach my $file (@helper_utilities)
{
	unlink("input/" . $file);
}

# Status message.
print "\nProcess complete!\n\n";
print "Press Enter to exit.\n";
<STDIN>;

# Subroutine to read configuration INI file and return a hash of key-value pairs.
sub read_ini
{
	# Store input parameter of INI file name.
	my $file = $_[0];
	
	# Declare hash.
	my %config;

	# Open configuration INI.
	open(my $fh, '<', $file) or die "Could not open file '$file' $!";

	# Read through file.
	while(my $line = <$fh>)
	{
		# Remove newline.
		chomp $line;

		# Skip empty lines and comments.
		next if $line =~ /^\s*$/;
		next if $line =~ /^\s*#/;

		# Split each line into key and value.
		if($line =~ /^\s*([^=]+?)\s*=\s*(.+?)\s*$/)
		{
			# Store key-value pair into hash.
			my ($key, $value) = ($1, $2);
			$config{$key} = $value;
		}
	}

	# Close configuration INI.
	close($fh);

	# Return hash.
	return %config;
}

# Subroutine to validate the hash generated from configuration INI.
sub validate_ini
{
	# Store input paramater of configuration hash.
	my %config = @_;

	# Store list of string type keys.
	my @string_keys = ('font_face', 'font_color', 'outline_color', 'aspect_ratio');

	# Store list of integer type keys.
	my @integer_keys = ('font_size', 'outline_strength', 'margin_vertical', 'margin_left', 'margin_right', 'bitrate');

	# Validate bold setting.
	if($config{'font_bold'} ne "yes" && $config{'font_bold'} ne "no")
	{
		return(0, "Configuration option \"font_bold\" should be \"yes\" or \"no\" (currently set to \"" . $config{'font_bold'} . "\").");
	}

	# Validate string keys.
	foreach my $key (@string_keys)
	{
		# Key does not exist
		if(!exists $config{$key})
		{
			return(0, "Configuration option \"" . $key . "\" is missing.");
		}

		# Invalid aspect ratio.
		if($key eq "aspect_ratio" && ($config{$key} !~ /^(\d+):(\d+)$/ || $1 <= 0 || $2 <= 0))
		{
			return(0, "Configuration option \"" . $key . "\" is not a valid aspect ratio (currently set to \"" . $config{$key} . "\").");
		}
	}

	# Validate integer keys.
	foreach my $key (@integer_keys)
	{
		# Key exists.
		if(exists $config{$key})
		{
			unless($config{$key} =~ /^\d+$/)
			{
				return(0, "Configuration option \"" . $key . "\" should be an integer number (currently set to \"" . $config{$key} . "\").");
			}
		}
		# Key does not exist.
		else
		{
			return(0, "Configuration option \"" . $key . "\" is missing.");
		}
	}

	# If all configuration keys are valid, return success without error message.
	return(1, "");
}