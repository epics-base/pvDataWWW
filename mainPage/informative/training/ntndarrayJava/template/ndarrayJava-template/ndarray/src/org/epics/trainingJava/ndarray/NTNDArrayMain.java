/*
 * Copyright information and license terms for this software can be
 * found in the file LICENSE that is included with the distribution
 */





package org.epics.trainingJava.ndarray;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

import org.epics.pvaccess.PVAException;
import org.epics.pvaccess.client.ChannelProvider;
import org.epics.pvaccess.server.impl.remote.ServerContextImpl;
import org.epics.pvdatabase.PVDatabase;
import org.epics.pvdatabase.PVDatabaseFactory;
import org.epics.pvdatabase.PVRecord;
import org.epics.pvdatabase.pva.ChannelProviderLocalFactory;



public class NTNDArrayMain {
    static void usage() {
        System.out.println("Usage:"
                + " -recordName name"
                + " -traceLevel traceLevel"
                );
    }

    static String recordName  = "testNDArray";
    private static int traceLevel = 0;

    public static void main(String[] args)
    {
        if(args.length==1 && args[0].equals("-help")) {
            usage();
            return;
        }
        int nextArg = 0;
        while(nextArg<args.length) {
            String arg = args[nextArg++];
            if(arg.equals("-recordName")) {
                recordName = args[nextArg++];
                continue;
            }
            if(arg.equals("-traceLevel")) {
                traceLevel = Integer.parseInt(args[nextArg++]);
                continue;
            } else {
                System.out.println("Illegal options");
                usage();
                return;
            }
        }
        try {
            PVDatabase master = PVDatabaseFactory.getMaster();
            ChannelProvider channelProvider = ChannelProviderLocalFactory.getChannelProviderLocal();
            PVRecord pvRecord = NTNDArrayRecord.create(recordName);
            pvRecord.setTraceLevel(traceLevel);
            master.addRecord(pvRecord);
            ServerContextImpl context = ServerContextImpl.startPVAServer(channelProvider.getProviderName(),0,true,null);
            while(true) {
                System.out.print("waiting for exit: ");
                BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
                String value = null;
                try {
                    value = br.readLine();
                } catch (IOException ioe) {
                    System.out.println("IO error trying to read input!");
                }
                if(value.equals("exit")) break;
            }
            context.destroy();
            master.destroy();
            channelProvider.destroy();
        } catch (PVAException e) {
            System.err.println(e.getMessage());
            System.exit(1);
        }
    }
}
