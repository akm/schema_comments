Dir.glob(File.join(__FILE__, '../../tasks/*.rake')){|f| puts f; require(f)}
