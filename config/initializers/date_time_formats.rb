ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
	:date => '%m/%d/%Y',
	:date_time12  => "%m/%d/%Y %I:%M%p",
	:date_time24  => "%m/%d/%Y %H:%M",
	:date_yahoo => "%Y-%m-%d"
)
