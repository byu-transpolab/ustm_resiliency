# Global Inputs

In the resiliency model, the only file that changes with each scenario is the
scenario highway network. These files are additional necessary inputs to the
model that do  not change with each scenario. They are as follows:

  - `HH_PROD.dbf` Household productions file. This is extracted from USTM, and
    contains trip productions by purpose. This file is committed to the repository
    and is available on checkout.
  - `transit_skim.mat` Transit travel time skim file. This is created by an offline
    process that averaged transit travel time skims in the WFRC model region
    into a USTM zone system. Travel times that are infeasible are coded as zero.
    This file is committed to the repository and is available on checkout.
  - `IIIXXIXX_LH_Ton_Truck_Utah.mat` Freight vehicle origin-destination matrix.
    Extracted from USTM. Cannot be stored in the repository due to size; download
    from [https://byu.box.com/shared/static/96ekw7aa2dou4dcmajzw5iikkx6w28ld.mat][https://byu.box.com/shared/static/96ekw7aa2dou4dcmajzw5iikkx6w28ld.mat]
