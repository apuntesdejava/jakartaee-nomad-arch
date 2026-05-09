
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.stream.Collectors;

public class UpdateIps {
    public static void main(String[] args) {
        validateArgs(args);
        var envName = getEnvName(args);
        var ip = getIp(args);
        new UpdateIps().update(envName, ip);
    }

    private void update(String envName, String ip) {
        var envFilePath = "Sales-HC/environments/" + envName + ".yml";
        var envFile = new File(envFilePath);
        if (!envFile.exists()) {
            throw new IllegalArgumentException("Environment file not found: " + envFilePath);
        }
        try {
            var lines = Files.readAllLines(envFile.toPath());
            var updatedLines = lines.stream()
                .map(line -> line.replaceAll("http://[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+", "http://" + ip))
                .collect(Collectors.toList());
            Files.write(envFile.toPath(), updatedLines);
            System.out.println("IP addresses updated successfully in " + envFilePath);
        } catch (IOException e) {
            throw new RuntimeException("Error updating environment file: " + envFilePath, e);
        }
    }


    private static void validateArgs(String[] args) {
        if (args.length < 2) {
            throw new IllegalArgumentException("Both environment name and IP address are required.");
        }
    }

    private static String getIp(String[] args) {
        return getArg(args, "ip");
    }

    private static String getEnvName(String[] args) {
        return getArg(args, "env");
    }

    private static String getArg(String[] args, String argName) {
        for (String arg : args) {
            if (arg.startsWith(argName + "=")) {
                return arg.substring((argName + "=").length());
            }
        }
        throw new IllegalArgumentException("Argument '" + argName + "' is required.");
    }
}
